# 架构

## 为什么拆成多仓库

参考 Spring 官方的做法。核心诉求：

1. **边界清晰** — `getbrick-core` 只能依赖 `getbrick-build`；`getbrick-boot` 才能依赖 `getbrick-core`。
   编译期就能挡住错误的依赖方向。
2. **发版独立** — 改一个 Web 模块不需要重新发 common。
3. **并行开发** — 多个小组可以各自拥有仓库、各自开 PR，CODEOWNERS 分别设。

代价是 BOM 升级需要跨仓库协调。用 Dependabot 的版本节奏 + 每周固定发版窗口来消化。

## 仓库清单

| 仓库 | 制品 | 说明 |
| --- | --- | --- |
| `getbrick-build` | `getbrick-build`、`getbrick-dependencies` | 父 POM 与 BOM，无业务代码 |
| `getbrick-core` | `getbrick-common` … `getbrick-web` | 基础框架模块，聚合在一个仓库内 |
| `getbrick-boot` | starter / auto-configuration | 规划中 |

`getbrick-core` 内部用聚合模块而非拆仓库，因为这些模块耦合紧、一起改的频率高，
拆开只会让本地开发变麻烦。真正独立的（core 与 boot）才拆仓库。

## 模块分层

`getbrick-core` 内部依赖只允许**从上往下**：

```
getbrick-web  →  getbrick-expression  →  getbrick-context  →  getbrick-beans  →  getbrick-core  →  getbrick-common
```

- `getbrick-common` — 异常、常量。与任何框架模块无关
- `getbrick-core` — 核心原语：生命周期、类型转换、`Ordered`、断言
- `getbrick-beans` — Bean 元数据、属性绑定、工厂
- `getbrick-context` — 应用上下文、环境配置、事件
- `getbrick-expression` — 表达式求值
- `getbrick-web` — Web 抽象

反向依赖、跨层跳依赖由 review 把关；`banDuplicateClasses` 与 `dependencyConvergence`
在构建期兜底。

## 版本策略

- 语义化版本，`MAJOR.MINOR.PATCH`
- **PATCH**：只修 bug，不改公开签名
- **MINOR**：加功能、加依赖，向后兼容
- **MAJOR**：删/改公开 API。只在确有破坏时用
- 公开 API 一律记在 Javadoc 里；模块内 `package-private` 随便改
- 多仓库同版本号（`getbrick-build` 与 `getbrick-core` 都发 `1.2.0`），靠 BOM 统一对齐
- `getbrick-build` 的版本是所有仓库的**下限**：下游不会用比它更旧的版本

## 新仓库接入清单

```bash
# 1. 建目录并拉入构建配置（checkstyle suppressions / license header / spotbugs filter）
../getbrick-build/scripts/install-build-config.sh /path/to/new-repo

# 2. 拷贝 wrapper，保证全组织 Maven 版本一致
cp -r ../getbrick-build/.mvn ../getbrick-build/mvnw ../getbrick-build/mvnw.cmd /path/to/new-repo/

# 3. 按 README 的 parent + BOM 片段写 pom.xml
# 4. 建远端仓库
gh repo create getbrick/getbrick-xxx --public --description "..." --source . --push
```

接入后本地必须能跑通：

```bash
./mvnw verify          # 含 checkstyle、spotless、enforcer
./mvnw -Pquality verify
```

## 配置是怎么分发到各仓库的

`config/` 目录（Checkstyle suppressions、license header、SpotBugs filter）以**文件**形式
随仓库提交，由 `scripts/install-build-config.sh` 复制。

之所以不用共享 jar 而不是共享配置：

- Spotless 的 `licenseHeader` 只接受文件路径，不支持 classpath 资源
- 共享配置 jar 会带来发布顺序依赖——新仓库必须等配置先发版才能构建

代价是 `config/` 存在副本。缓解方式：BOM 升级 PR 里顺手跑一次
`install-build-config.sh`，脚本会 diff 并提示哪些文件变了。
