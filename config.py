#!/usr/bin/env python3
"""
Configuration loader for Paper Management System

Supports multiple config sources (in order of precedence):
1. config.yaml in project directory
2. Environment variables with PAPERMGR_ prefix
3. Default values

Usage:
    from config import Config
    cfg = Config()
    db_path = cfg.get("database.path")
    papers_dir = cfg.get("papers.dir")
"""

import os
import yaml
from pathlib import Path
from typing import Any, Optional

# Default configuration values
DEFAULTS = {
    "database.path": "/data/disk/papers/index.db",
    "papers.dir": "/data/disk/papers",
    "papers.extensions": [".pdf"],
    "downloads.dir": "/root/Downloads",
    "downloads.keywords": ["科研通", "ablesci"],
    "logging.path": "/data/disk/papers/auto_index.log",
    "logging.level": "INFO",
    "ai.enabled": False,
    "ai.provider": "openai",
    "ai.model": "gpt-3.5-turbo",
    "ai.api_key": "",
    "ai.max_text_length": 50000,
    "notification.enabled": False,
    "notification.cmd": "",
}


class Config:
    """Configuration manager with environment variable override support"""
    
    _instance: Optional['Config'] = None
    _config: dict = {}
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._load()
        return cls._instance
    
    def _load(self):
        """Load configuration from file and environment"""
        self._config = DEFAULTS.copy()
        
        # Load from config.yaml
        config_paths = [
            Path(__file__).parent / "config.yaml",
            Path(__file__).parent.parent / "config.yaml",
        ]
        
        for path in config_paths:
            if path.exists():
                with open(path, 'r') as f:
                    file_config = yaml.safe_load(f)
                    if file_config:
                        self._merge_config(self._config, file_config)
                break
        
        # Override with environment variables (PAPERMGR_ prefix)
        for key in list(self._config.keys()):
            env_key = f"PAPERMGR_{key.upper().replace('.', '_')}"
            if env_key in os.environ:
                value = os.environ[env_key]
                # Type inference from defaults
                default_value = self._config.get(key)
                if isinstance(default_value, bool):
                    value = value.lower() in ('true', '1', 'yes')
                elif isinstance(default_value, list):
                    value = value.split(',')
                self._config[key] = value
    
    def _merge_config(self, base: dict, override: dict):
        """Merge override config into base"""
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._merge_config(base[key], value)
            else:
                base[key] = value
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value by dot-notation key"""
        return self._config.get(key, default)
    
    def get_required(self, key: str) -> Any:
        """Get required configuration value, raises if not found"""
        value = self._config.get(key)
        if value is None:
            raise ValueError(f"Required configuration '{key}' not found. Please set in config.yaml or environment.")
        return value
    
    @property
    def db_path(self) -> str:
        return self.get("database.path")
    
    @property
    def papers_dir(self) -> str:
        return self.get("papers.dir")
    
    @property
    def downloads_dir(self) -> str:
        return self.get("downloads.dir")
    
    @property
    def notification_cmd(self) -> str:
        return self.get("notification.cmd")
    
    @property
    def notification_enabled(self) -> bool:
        return self.get("notification.enabled")
    
    @property
    def ai_enabled(self) -> bool:
        return self.get("ai.enabled")
    
    @property
    def ai_api_key(self) -> str:
        # Try environment variable first
        api_key = os.environ.get("OPENAI_API_KEY", "")
        if not api_key:
            api_key = self.get("ai.api_key", "")
        return api_key


def get_config() -> Config:
    """Get the singleton Config instance"""
    return Config()


# CLI for testing
if __name__ == "__main__":
    cfg = get_config()
    print("Current configuration:")
    for key, value in sorted(cfg._config.items()):
        print(f"  {key}: {value}")
