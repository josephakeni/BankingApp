domain_name  = "brightstaraid.org"
use_route53  = true
alb_hostname = "k8s-banking-bankingi-c50d516e9e-888771560.eu-west-1.elb.amazonaws.com"

# main_vpc (vpc-0a0927aa04df49de2, 10.0.0.0/16)
private_subnet_ids = [
  "subnet-025840f4e4e83190f", # jotonia-private-subnet--001  eu-west-1a  10.0.16.0/24
  "subnet-02f474c73cf56be9e", # jotonia-private-subnet--002  eu-west-1b  10.0.32.0/24
]

public_subnet_ids = [
  "subnet-03817a53d0e3de3a0", # jotonia-public-subnet--001  eu-west-1a  10.0.0.0/24
  "subnet-091ec5091a8ab177b", # jotonia-public-subnet--002  eu-west-1b  10.0.1.0/24
  "subnet-04153f243074f407f", # jotonia-public-subnet--003  eu-west-1c  10.0.2.0/24
]
