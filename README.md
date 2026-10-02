# Damsel

Systemwide protocol collection.


## Требования к оформлению Thrift IDL файлов

- __Namespace:__ 

	В каждом файле нужно __обязательно__ указывать `namespace` для __JAVA__:
		
		namespace java dev.vality.damsel.<name>
			
	Где `<name>` - имя, уникальное для Thrift IDL файла в Damsel.
	
	
## Java development

Собрать дамзель и установить новый jar в локальный мавен репозиторий:

* make wc_compile
* make wc_java_install LOCAL_BUILD=true SETTINGS_XML=path_to_rbk_maven_settings

Чтобы использовать несколько версий дамзели в проекте, используйте classifier:v${commit.number}

```
<dependency>
    <groupId>dev.vality</groupId>
    <artifactId>damsel</artifactId>
    <version>1.136-07b0898</version>
    <classifier>v136</classifier>
</dependency>
```

## Frontend development

Протокол публикуется в npm как [`@vality/domain-proto`](https://www.npmjs.com/package/@vality/domain-proto). TypeScript-клиенты и метаданные генерируются из `proto` с помощью [`@vality/tsthrift-cli`](https://www.npmjs.com/package/@vality/tsthrift-cli).

Сгенерировать пакет локально (результат в `dist`):

* npm ci
* npm run codegen

Проверить изменения в проекте до публикации можно через локальный архив:

```
npm pack                                   # vality-domain-proto-<version>.tgz
npm install ../damsel/vality-domain-proto-<version>.tgz    # в проекте-потребителе
```

Публикация происходит автоматически при пуше в `master` (workflow `Frontend: Publish`). Версия пакета содержит короткий sha коммита, например `2.0.2-8d6174b.0`:

```
npm install @vality/domain-proto@2.0.2-8d6174b.0
```

Импорт — по namespace thrift-файла:

```ts
import { Invoicing } from '@vality/domain-proto/payment_processing';
import { DomainObjectType } from '@vality/domain-proto/domain';
```
