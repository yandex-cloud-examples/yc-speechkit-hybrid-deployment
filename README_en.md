# Deploying Yandex SpeechKit Hybrid demo bench with Terraform 

[SpeechKit Hybrid](https://yandex.cloud/docs/speechkit-hybrid/) are the [Yandex SpeechKit](https://yandex.cloud/docs/speechkit/) speech recognition and synthesis technologies running in your infrastructure. SpeechKit Hybrid is built around Docker containers, meeting security and data management requirements.

To check out how SpeechKit Hybrid works, deploy and test the speech recognition and synthesis apps in Docker containers. To do this, create a Yandex Cloud infrastructure using Terraform. For a detailed guide, see the [SpeechKit Hybrid documentation](https://yandex.cloud/docs/speechkit-hybrid/quickstart).

The repository houses the following Terraform configuration files for building the infrastructure:

* `main.tf`: Provider settings.
* `networks.tf`: Configures the network, subnets, internal DNS zone, and security groups.
* `node-deploy.tf`: Configures the Yandex Cloud and SpeechKit Hybrid VMs, including data for `docker-compose`.
* `terraform.tfvars.template`: Template for your file with the variables, where their values will be specified.
* `variables.tf`: Variables to configure Terraform, their types and default values.
