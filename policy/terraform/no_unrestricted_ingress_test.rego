# policy/terraform/no_unrestricted_ingress_test.rego

package terraform.security_groups.unrestricted_ingress

import rego.v1

# ── Passing ───────────────────────────────────────────────────────────────────

# Port 80 open to 0.0.0.0/0 is the intentional ALB HTTP rule — must pass
test_alb_http_80_passes if {
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

# MySQL restricted to a security group reference (no cidr_blocks) passes
test_mysql_sg_source_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.database.aws_security_group_rule.db_ingress",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 3306,
				"to_port": 3306,
				"protocol": "tcp",
				"cidr_blocks": [],
				"ipv6_cidr_blocks": [],
				"source_security_group_id": "sg-ecs",
			}},
		}],
	}
}

# ── Failing ───────────────────────────────────────────────────────────────────

test_mysql_open_to_world_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.database.aws_security_group_rule.bad_mysql",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 3306,
				"to_port": 3306,
				"protocol": "tcp",
				"cidr_blocks": ["0.0.0.0/0"],
				"ipv6_cidr_blocks": [],
			}},
		}],
	}
	count(msgs) == 1
}

test_https_open_to_world_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.compute.aws_security_group_rule.bad_https",
			"type": "aws_security_group_rule",
			"change": {"after": {
				"type": "ingress",
				"from_port": 443,
				"to_port": 443,
				"protocol": "tcp",
				"cidr_blocks": ["0.0.0.0/0"],
				"ipv6_cidr_blocks": [],
			}},
		}],
	}
	count(msgs) == 1
}
