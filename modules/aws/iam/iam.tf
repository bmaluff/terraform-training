locals {
  role_policies = [for role, role_info in var.roles : {
    for policy_name, policy_info in role_info.policies :
    "${role_info.name}-${policy_info.name}" => {
      role = role_info.name
      name   = policy_info.name
      statement = policy_info.statement
    } 
    } if try(role_info.policies, null) != null
  ]
  
  managed_role_policies = [for role, role_info in var.roles : {
    for index, arn in role_info.managed_policies :
    "${role_info.name}-${index}" => {
      role = role_info.name
      policy_arn = arn
    } 
    } if try(role_info.managed_policies, null) != null
  ]

  user_policies = [for user, user_info in var.users : {
    for policy_name, policy_info in user_info.policies :
    "${user_info.name}-${policy_info.name}" => {
      user = user_info.name
      name   = policy_info.name
      statement = policy_info.statement
    } 
    } if try(user_info.policies, null) != null
  ]

  user_managed_policies = [for user, user_info in var.users : {
    for index, arn in user_info.managed_policies :
    "${user_info.name}-${index}" => {
      user = user_info.name
      policy_arn = arn
    } 
    } if try(user_info.managed_policies, null) != null
  ]

  instance_profles = {for role, role_info in var.roles :
    role => "${role_info.name}-instance-profile" if try(role_info.create_instance_profile, false) == true
  }

}
data "aws_iam_policy_document" "iam_assume_policy" {
  for_each = var.roles
  version  = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = try(each.value.iam_assume_policy_type, "Service")
      identifiers = try(each.value.iam_assume_policy_identifiers, ["ec2.amazonaws.com"])
    }
  }
}

resource "aws_iam_role" "iam_role" {
  for_each           = var.roles
  assume_role_policy = data.aws_iam_policy_document.iam_assume_policy[each.key].json
  path               = try(each.value.path, "/")
  name               = each.value.name
}

resource "aws_iam_role_policy_attachment" "custom_role_pol_att" {
  # for_each = try({for v in local.role_policies : keys(v)[0] => values(v)[0]},{})
  for_each = {for v in local.role_policies : keys(v)[0] => values(v)[0]}
  role       = each.value.role
  policy_arn = aws_iam_policy.role_policy[each.key].arn
  depends_on = [ 
    aws_iam_role.iam_role
   ]
}

resource "aws_iam_role_policy_attachment" "managed_role_pol_att" {
  for_each = merge(local.managed_role_policies...)
  role       = each.value.role
  policy_arn = each.value.policy_arn
  depends_on = [ 
    aws_iam_role.iam_role
   ]
}

data "aws_iam_policy_document" "iam_role_permissions" {
  # for_each = try({for v in local.role_policies : keys(v)[0] => values(v)[0]}, {})
  for_each = {for v in local.role_policies : keys(v)[0] => values(v)[0]}
  version = try(each.value.version, "2012-10-17")
  dynamic "statement" {
    for_each = each.value.statement
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = try(statement.value.condition, {})
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
      dynamic "principals" {
        for_each = try(statement.value.principals, {})
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, {})
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }
    }
  }
}

resource "aws_iam_policy" "role_policy" {
  # for_each = try({for v in local.role_policies : keys(v)[0] => values(v)[0]}, {})
  for_each = {for v in local.role_policies : keys(v)[0] => values(v)[0]}
  name   = each.value.name #var.ecs_task_exec_extra_permissions_policy_name
  path   = try(each.value.path, "/")
  policy = data.aws_iam_policy_document.iam_role_permissions[each.key].json
}

resource "aws_iam_user" "user" {
  for_each = var.users
  name     = each.value.name
  path     = try(each.value.path, "/")
  tags     = try(each.value.tags, {})
  force_destroy = try(each.value.force_destroy, false)
  permissions_boundary = try(each.value.permissions_boundary, null)
}

data "aws_iam_policy_document" "user_permissions" {
  for_each = try(local.user_policies[0], {})
  version = try(each.value.version, "2012-10-17")
  dynamic "statement" {
    for_each = each.value.statement
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = try(statement.value.condition, {})
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
      dynamic "principals" {
        for_each = try(statement.value.principals, {})
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }
      dynamic "not_principals" {
        for_each = try(statement.value.not_principals, {})
        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }
    }
  }
}

resource "aws_iam_policy" "user_policy" {
  for_each = try(local.user_policies[0], {})
  name   = each.value.name #var.ecs_task_exec_extra_permissions_policy_name
  path   = try(each.value.path, "/")
  policy = data.aws_iam_policy_document.user_permissions[each.key].json
}

resource "aws_iam_user_policy_attachment" "user_custom_policy_att" {
  for_each = try(local.user_policies[0], {})
  user       = each.value.user
  policy_arn = aws_iam_policy.user_policy[each.key].arn
  depends_on = [ 
    aws_iam_user.user
   ]
}

resource "aws_iam_user_policy_attachment" "user_managed_policy_att" {
  for_each = try(local.user_managed_policies[0], {})
  user       = each.value.user
  policy_arn = each.value.policy_arn
  depends_on = [ 
    aws_iam_user.user
   ]
}

resource "aws_iam_instance_profile" "this" {
  for_each = try(local.instance_profles, {})
  name = each.value
  role = aws_iam_role.iam_role[each.key].name
}