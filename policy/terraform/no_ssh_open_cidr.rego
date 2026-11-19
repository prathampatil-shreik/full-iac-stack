# policy/terraform/no_ssh_open_cidr.rego
#
# No aws_security_group_rule resource may allow inbound SSH (port 22)
# from 0.0.0.0/0 (all IPv4) or ::/0 (all IPv6).
#
# Maps to: modules/compute/main.tf aws_security_group_rule resources.
# The ALB SG allows port 80 from 0.0.0.0/0 — that is intentional and
# this rule does not block it.

package terraform.security_groups

import rego.v1

open_cidrs := {"0.0.0.0/0", "::/0"}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group_rule"
	config := resource.change.after

	config.type == "ingress"
	config.from_port <= 22
	config.to_port >= 22

	cidr := config.cidr_blocks[_]
	cidr in open_cidrs

	msg := sprintf(
		"[no_ssh_open_cidr] %s: SSH (port 22) must not be open to %s",
		[resource.address, cidr],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group_rule"
	config := resource.change.after

	config.type == "ingress"
	config.from_port <= 22
	config.to_port >= 22

	cidr := config.ipv6_cidr_blocks[_]
	cidr in open_cidrs

	msg := sprintf(
		"[no_ssh_open_cidr] %s: SSH (port 22) must not be open to %s",
		[resource.address, cidr],
	)
}
