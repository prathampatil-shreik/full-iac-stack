# policy/terraform/mandatory_tags_test.rego

package terraform.tags

import rego.v1

compliant_tags := {
	"Project":     "iac-platform",
	"Environment": "dev",
	"ManagedBy":   "Terraform",
}

# ── Passing ───────────────────────────────────────────────────────────────────

test_vpc_with_all_tags_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.vpc.aws_vpc.this",
			"type": "aws_vpc",
			"change": {
				"actions": ["create"],
				"after": {"tags": compliant_tags},
			},
		}],
	}
}

test_rds_with_all_tags_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {
				"actions": ["create"],
				"after": {"tags": compliant_tags},
			},
		}],
	}
}

# ── Failing ───────────────────────────────────────────────────────────────────

test_vpc_missing_tags_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.vpc.aws_vpc.this",
			"type": "aws_vpc",
			"change": {
				"actions": ["create"],
				"after": {"tags": {"Name": "my-vpc"}},
			},
		}],
	}
	count(msgs) == 1
}

test_s3_missing_managed_by_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.storage.aws_s3_bucket.this",
			"type": "aws_s3_bucket",
			"change": {
				"actions": ["create"],
				"after": {"tags": {
					"Project":     "iac-platform",
					"Environment": "dev",
				}},
			},
		}],
	}
	count(msgs) == 1
}

# Delete actions are excluded from tag enforcement
test_delete_action_not_checked if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.vpc.aws_vpc.this",
			"type": "aws_vpc",
			"change": {
				"actions": ["delete"],
				"after": {"tags": {}},
			},
		}],
	}
}
