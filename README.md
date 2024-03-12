# Начало работы с Yandex SpeechKit Hybrid

[SpeechKit Hybrid](https://cloud.yandex.ru/ru/docs/speechkit-hybrid/) — это технологии [Yandex SpeechKit](https://cloud.yandex.ru/ru/docs/speechkit/) для распознавания и синтеза речи, которые работают внутри вашей инфраструктуры. В основе SpeechKit Hybrid лежат контейнеры Docker, они подходят для выполнения требований к безопасности и управлению данными.

Чтобы начать работу со SpeechKit Hybrid, разверните и протестируйте приложения распознавания и синтеза речи в Docker-контейнерах. Для этого создайте инфраструктуру Yandex Cloud с помощью Terraform. Инструкция приведена в [документации SpeechKit Hybrid](https://cloud.yandex.ru/ru/docs/speechkit-hybrid/quickstart).

В репозитории расположены следующие конфигурационные Terraform-файлы для создания инфраструктуры:

* `main.tf` — настройки провайдеров.
* `networks.tf` — конфигурация сети, подсети, внутренней зоны DNS и группы безопасности.
* `node-deploy.tf` — конфигурация ВМ Yandex Cloud и SpeechKit Hybrid, в том числе данные для `docker-compose`.
* `terraform.tfvars.template` — шаблон, из которого создается файл с переменными. В полученном файле указываются значения переменных.
* `variables.tf` — переменные, используемые в конфигурации Terraform, их типы и значения по умолчанию.
