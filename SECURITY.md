# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within paper-management-system, please report it responsibly.

**Please do NOT open a public GitHub issue** for security vulnerabilities.

Instead, please report it via one of the following:

- **Private vulnerability reporting**: Use GitHub's [Private vulnerability reporting](https://github.com/crayfish-ai/paper-management-system/security/advisories/new) (preferred)
- **Email**: Contact the maintainer via GitHub

When reporting, please include:

1. A description of the vulnerability
2. Steps to reproduce the issue
3. Potential impact of the vulnerability
4. Any suggested fixes (optional)

## Security Best Practices

When deploying paper-management-system:

- **Protect your PDF library**: The system reads and indexes PDF files. Ensure the `PAPERS_DIR` points to a secure location
- **Database access**: The SQLite database contains metadata. Limit file permissions appropriately
- **AI summarization**: If enabled, API keys for LLM providers should be stored securely in environment variables
- **No remote code execution**: The system only processes local files and generates text; it does not execute external code

## Credential Storage

This skill uses the following sensitive values:

| Variable | Description | Risk |
|----------|-------------|------|
| `PAPERMGR_OPENAI_API_KEY` | OpenAI API key for AI summarization (optional) | High if used |
| `PAPERMGR_ANTHROPIC_API_KEY` | Anthropic API key for AI summarization (optional) | High if used |

**Never** commit API keys to the repository. Use environment variables instead.
