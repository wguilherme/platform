terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

data "coder_workspace" "me" {}

data "coder_parameter" "ai_prompt" {
  name         = "AI Prompt"
  display_name = "Prompt / Issue Jira"
  type         = "string"
  form_type    = "textarea"
  description  = "Descreva a task ou informe o ID da issue Jira (ex: PROJ-42)"
  mutable      = false
  default      = ""
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "arm64"
  env = {
    GIT_AUTHOR_NAME  = data.coder_workspace.me.owner
    GIT_AUTHOR_EMAIL = "${data.coder_workspace.me.owner}@users.noreply.github.com"
  }
}

module "claude-code" {
  source                  = "registry.coder.com/coder/claude-code/coder"
  version                 = "~> 4.0"
  agent_id                = coder_agent.main.id
  workdir                 = "/home/coder/project"
  claude_code_oauth_token = var.claude_oauth_token
}

resource "coder_ai_task" "task" {
  app_id = module.claude-code.task_app_id
}

resource "kubernetes_pod" "workspace" {
  metadata {
    name      = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
    namespace = "coder"
    labels = {
      "app.kubernetes.io/name" = "coder-workspace"
    }
  }
  spec {
    restart_policy = "Never"
    container {
      name  = "dev"
      image = "ghcr.io/coder/envbuilder:latest"
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }
      env {
        name = "CLAUDE_CODE_OAUTH_TOKEN"
        value_from {
          secret_key_ref {
            name = "claude-oauth"
            key  = "token"
          }
        }
      }
      resources {
        requests = { memory = "512Mi", cpu = "250m" }
        limits   = { memory = "2Gi",   cpu = "1000m" }
      }
      volume_mount {
        name       = "home"
        mount_path = "/home/coder"
      }
    }
    volume {
      name = "home"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home.metadata[0].name
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}-home"
    namespace = "coder"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-path"
    resources {
      requests = { storage = "5Gi" }
    }
  }
}

variable "claude_oauth_token" {
  type      = string
  sensitive = true
  default   = ""
}
