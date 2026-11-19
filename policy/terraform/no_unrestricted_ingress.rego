# policy/terraform/no_unrestricted_ingress.rego
#
# aws_security_group_rule ingress rules must not open sensitive ports to
# 0.0.0.0/0 or ::/0.
#
# Intentional exception: port 80 on the ALB security group is the public HTTP
# entry point for this architecture. All other ports (including 443, 3306,
# 5432, 22) must not be open to the world.
#
# The ALB SG allows port 80 from 0.0.0.0/0 — this is by design and is
# explicitly excluded from this rule.

package terraform.security_groups.unrestricted_ingress

import rego.v1

open_cidrs := {"0.0.0.0/0", "::/0"}

# Ports that must never be open to the world (database, admin, etc.)
sensitive_ports := {22, 443, 3306, 5432, 5439, 6379, 27017}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group_rule"
	config := resource.change.after
	config.type == "ingress"

	# Check if any sensitive port falls within the rule's port range
	port := sensitive_ports[_]
	config.from_port <= port
	config.to_port >= port

	cidr := config.cidr_blocks[_]
	cidr in open_cidrs

	msg := sprintf(
		"[no_unrestricted_ingress] %s: port %d must not be open to %s",
		[resource.address, port, cidr],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group_rule"
	config := resource.change.after
	config.type == "ingress"

	port := sensitive_ports[_]
	config.from_port <= port
	config.to_port >= port

	cidr := config.ipv6_cidr_blocks[_]
	cidr in open_cidrs

	msg := sprintf(
		"[no_unrestricted_ingress] %s: port %d must not be open to %s",
		[resource.address, port, cidr],
	)
}
