# Getbrick Build

构建基础设施：所有 Getbrick 仓库共用的**父 POM**与**依赖 BOM**。参考 Spring 官方
`spring-boot-dependencies` / `spring-boot-parent` 的拆分方式，多仓库各自独立发版。

```
getbrick-build                 本仓库：父 POM（构建配置）+ getbrick-dependencies（版本管理）
├── getbrick-core              基础框架模块：common / core / beans / context / expression / web
└── getbrick-boot              starter 与自动配置（规划中）
```

## 两个制品

| 制品 | 作用 | 谁用 |
| --- | --- | --- |
| `com.getbrick:getbrick-build` | 构建配置：插件版本、编译参数、格式化、校验、发布 profile | 作为 `<parent>` |
| `com.getbrick:getbrick-dependencies` | 纯版本管理：所有第三方依赖版本 | `import` 进 `<dependencyManagement>` |

父 POM **不含** `dependencyManagement`。这样纯库只想借版本、不想继承插件时，
可以只 import BOM 而不挂 parent。

## 在新仓库中使用

```xml
<parent>
    <groupId>com.getbrick</groupId>
    <artifactId>getbrick-build</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <relativePath/>
</parent>

<artifactId>getbrick-my-module</artifactId>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.getbrick</groupId>
            <artifactId>getbrick-dependencies</artifactId>
            <version>${project.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

<dependencies>
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

依赖全部继承的约定：**不要写 `<version>`**。版本只存在于 BOM。

## 常用命令

| 命令 | 作用 |
| --- | --- |
| `./mvnw verify` | 默认门禁：编译 + 单测 + Checkstyle + Spotless + Enforcer + JaCoCo 报告 |
| `./mvnw spotless:apply` | 自动格式化并补 Apache-2.0 license header |
| `./mvnw -Pquality verify` | 追加 SpotBugs 静态分析与依赖使用分析 |
| `./mvnw -Pstrict validate` | 追加 `requireUpperBoundDeps`，升级依赖时用 |
| `./mvnw -Prelease deploy` | 签名并上传 Maven Central |
| `./mvnw -Prelease-github deploy` | 发布快照到 GitHub Packages |

单项跳过（本地救急，CI 上不要用）：`-Dcheckstyle.skip`、`-Dspotless.check.skip`、
`-Denforcer.skip`、`-Djacoco.skip`、`-DskipTests`。

## 已内置的约束

- **工具链**：JDK 25、UTF-8、`-parameters`、`-Xlint:all`；Maven 版本由 wrapper 锁定为 3.9.11
- **可复现构建**：固定 `project.build.outputTimestamp`，CI 会校验两次构建产物 sha256 一致
- **依赖收敛**：默认 `dependencyConvergence` + `banDuplicatePomDependencyVersions`；
  `verify` 阶段 `banDuplicateClasses`
- **代码风格**：Spotless（Palantir 格式化 + import 顺序 + license header）
  与 Checkstyle（Checkstyle 自带 `google_checks.xml`，只维护一份 suppressions）
- **覆盖率**：JaCoCo 产出 XML/HTML，报告作为 CI artifact 上传
- **发布**：`flatten-maven-plugin` 解析安装用的 POM，GPG 签名，sources + javadoc 附件，
  Central Portal 上传后人工确认发布

## 依赖治理

Dependabot 每周一开 PR，分 patch / minor 两组。合并前必看：

1. `./mvnw -Pstrict validate` 是否仍通过（版本收敛没有被打破）
2. 有没有跨越主版本的升级（会有单独的 major PR，需人工评估）
3. BOM 改动要同步通知所有下游仓库，见 [docs/architecture.md](docs/architecture.md)

## 文档

- [docs/architecture.md](docs/architecture.md) — 仓库划分、版本策略、新仓库接入清单
- [CONTRIBUTING.md](CONTRIBUTING.md) — 提交与 PR 约定

## License

[Apache-2.0](LICENSE)
