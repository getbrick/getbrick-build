# Contributing

## 环境

```bash
git clone git@github.com:getbrick/getbrick-build.git
cd getbrick-build
./mvnw verify
```

不需要预装 Maven，wrapper 会自动下载锁定的 3.9.11。需要 JDK 25。

## 提交约定

Conventional Commits，因为 Dependabot 与 release notes 都依赖它解析：

```
feat(build): add spotbugs to the quality profile
fix(deps): align slf4j with logback 1.5.38
chore(deps): bump maven-compiler-plugin from 3.15.0 to 3.16.0
ci: run quality gate on pull_request
docs: explain the module layering rules
```

`deps` 变更走 Dependabot 的 PR，不手工改版本号。

## 改版本号的位置

| 想改什么 | 改哪里 |
| --- | --- |
| 第三方依赖版本 | `getbrick-dependencies/pom.xml` 的 `<properties>` |
| 构建插件版本 | 根 `pom.xml` 的 `<properties>` |
| 规则本身 | `config/`（用 `./scripts/install-build-config.sh` 分发） |

版本号只出现一次。别在 `<dependencies>` 里写字面量版本。

## 门禁

`./mvnw verify` 必须绿。CI 还会跑：

- `-Pstrict validate` — 依赖必须收敛到最高版本
- `-Pquality verify` — SpotBugs + 依赖使用分析
- 可复现构建校验 — 两次构建产物 sha256 必须一致

PR 里如果绕过门禁（比如提交了 skip 参数），review 会打回。

## 改 BOM 的流程

BOM 一动，所有下游仓库都要重新验证：

```bash
./mvnw -Prelease-github deploy          # 先发快照
# 在下游仓库
mvn -U verify
```

发版用打 tag 触发 `.github/workflows/release.yml`：

```bash
git tag v1.0.0 && git push origin v1.0.0
```

签名密钥、Central Portal token 从 GitHub Secrets 读，不要写进仓库。
