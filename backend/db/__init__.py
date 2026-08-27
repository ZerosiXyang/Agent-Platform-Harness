"""数据库与三层记忆系统 - 表结构与迁移脚本。

模块边界见 docs/architecture/boundaries.md：
- PostgresSaver（短期）与 PostgresStore（长期）表结构定义区
- 修改表结构必须生成 SQLAlchemy 迁移脚本
"""
