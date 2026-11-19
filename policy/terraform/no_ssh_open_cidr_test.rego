# policy/terraform/no_ssh_open_cidr_test.rego

package terraform.security_groups

import rego.v1

# ── Passing ───────────────────────────────────────────────────────────────────

# Port 80 open to 0.0.0.0/0 is the intentional ALB rule — must NOT be denied
test_http_alb_rule_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.compute.aws_security_group_rule.alb_ingress_http",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 80,
				"to_port": 80,
				"protocol": "tcp",
				"cidr_blocks": ["0.0.0.0/0"],
				"ipv6_cidr_blocks": [],
			}},
		}],
	}
}

# SSH restricted to a specific CIDR is allowed
test_ssh_restricted_cidr_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.compute.aws_security_group_rule.ssh_restricted",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 22,
				"to_port": 22,
				"protocol": "tcp",
				"cidr_blocks": ["10.0.0.0/8"],
				"ipv6_cidr_blocks": [],
			}},
		}],
	}
}

# ── Failing ───────────────────────────────────────────────────────────────────

test_ssh_open_ipv4_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.compute.aws_security_group_rule.bad_ssh",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 22,
				"to_port": 22,
				"protocol": "tcp",
				"cidr_blocks": ["0.0.0.0/0"],
				"ipv6_cidr_blocks": [],
			}},
		}],
	}
	count(msgs) == 1
}

test_ssh_open_ipv6_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.compute.aws_security_group_rule.bad_ssh_v6",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 0,
				"to_port": 65535,
				"protocol": "tcp",
				"cidr_blocks": [],
				"ipv6_cidr_blocks": ["::/0"],
			}},
		}],
	}
	count(msgs) == 1
}

# Egress rules are not checked
test_egress_all_open_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.compute.aws_security_group_rule.ecs_egress",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "egress",
				"from_port": 0,
				"to_port": 0,
				"protocol": "-1",
				"cidr_blocks": ["0.0.0.0/0"],
				"ipv6_cidr_blocks": [],
			}},
		}],
	}
}
