# Recommended GCP Network Setup
# This provides a good balance of simplicity and production readiness

locals {
  # CIDR blocks
  vpc_cidr = "10.0.0.0/16"
  
  # Subnet configuration
  subnets = {
    public = {
      name                     = "${var.cluster_name}-public"
      cidr                     = "10.0.1.0/24"
      description              = "Public subnet for load balancers and bastion hosts"
      private_ip_google_access = false
    }
    
    private = {
      name                     = "${var.cluster_name}-private"
      cidr                     = "10.0.2.0/24"
      description              = "Private subnet for GKE nodes and services"
      private_ip_google_access = true
      secondary_ranges = {
        gke-pods     = "10.1.0.0/16"
        gke-services = "10.2.0.0/16"
      }
    }
    
    data = {
      name                     = "${var.cluster_name}-data"
      cidr                     = "10.0.3.0/24"
      description              = "Private subnet for databases and data services"
      private_ip_google_access = true
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  description             = "VPC for ${var.cluster_name} infrastructure"
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each                 = local.subnets
  name                     = each.value.name
  ip_cidr_range           = each.value.cidr
  region                  = var.region
  network                 = google_compute_network.vpc.id
  description             = each.value.description
  private_ip_google_access = each.value.private_ip_google_access

  # Secondary IP ranges for GKE (only for private subnet)
  dynamic "secondary_ip_range" {
    for_each = lookup(each.value, "secondary_ranges", {})
    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }

  # Enable flow logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata            = "INCLUDE_ALL_METADATA"
  }
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  name        = "${var.cluster_name}-router"
  region      = var.region
  network     = google_compute_network.vpc.id
  description = "Router for ${var.cluster_name} NAT gateway"
}

# Cloud NAT for private subnet internet access
resource "google_compute_router_nat" "nat" {
  name                               = "${var.cluster_name}-nat"
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # Only provide NAT for private subnets
  subnetwork {
    name                    = google_compute_subnetwork.subnets["private"].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.subnets["data"].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_subnetwork.subnets]
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.cluster_name}-allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    local.subnets.public.cidr,
    local.subnets.private.cidr,
    local.subnets.data.cidr,
    "10.1.0.0/16", # GKE pods
    "10.2.0.0/16"  # GKE services
  ]
  
  description = "Allow internal communication between subnets"
}

resource "google_compute_firewall" "allow_ssh_bastion" {
  name    = "${var.cluster_name}-allow-ssh-bastion"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bastion"]
  description   = "Allow SSH to bastion hosts"
}

resource "google_compute_firewall" "allow_load_balancer_health_checks" {
  name    = "${var.cluster_name}-allow-lb-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22",  # Google Cloud Load Balancer health check ranges
    "35.191.0.0/16"
  ]
  
  description = "Allow health checks from Google Cloud Load Balancers"
}

resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.cluster_name}-deny-all-ingress"
  network = google_compute_network.vpc.name
  
  deny {
    protocol = "all"
  }
  
  source_ranges = ["0.0.0.0/0"]
  priority     = 65534
  description  = "Default deny all ingress traffic"
} 