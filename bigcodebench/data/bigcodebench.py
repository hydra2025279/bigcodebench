import hashlib
import json
import os
from typing import Dict

from bigcodebench.data.utils import (
    CACHE_DIR,
    completeness_check,
    get_dataset_metadata,
    make_cache,
    stream_jsonl,
)
from datasets import load_dataset

BIGCODEBENCH_OVERRIDE_PATH = os.environ.get("BIGCODEBENCH_OVERRIDE_PATH", None)
BIGCODEBENCH_HF = "bigcode/bigcodebench"
BIGCODEBENCH_VERSION = "v0.1.4"

def _ready_bigcodebench_path(subset="full", version="default") -> str:
    if BIGCODEBENCH_OVERRIDE_PATH:
        return BIGCODEBENCH_OVERRIDE_PATH

    version = BIGCODEBENCH_VERSION if version == "default" else version
    url, path = get_dataset_metadata(version, subset)
    dataset = load_dataset(BIGCODEBENCH_HF, split=version)
    make_cache(url, dataset, path)

    return path


def get_bigcodebench(err_incomplete=True, subset="full", version="default") -> Dict[str, Dict]:
    """Get BigCodeBench from BigCode's github repo and return as a dict of parsed tasks."""
    data_path = _ready_bigcodebench_path(subset=subset, version=version)
    data = {task["task_id"]: task for task in stream_jsonl(data_path)}
    if err_incomplete:
        completeness_check("BigCodeBench", data)
    return data


def get_bigcodebench_hash(subset="full", version="default") -> str:
    """Get the hash of BigCodeBench dataset."""
    data_path = _ready_bigcodebench_path(subset, version)
    with open(data_path, "rb") as f:
        data = f.read()
    return hashlib.md5(data).hexdigest()
