"""Optional sample -> group mapping shared by the plotting scripts."""
import csv


def load_groups(path=None):
    """Read a TSV with columns sample_id<TAB>group. Returns {} if path is None."""
    groups = {}
    if not path:
        return groups
    with open(path, newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            groups[str(row["sample_id"])] = row["group"]
    return groups


def label(sample_id, groups):
    g = groups.get(str(sample_id))
    return f"{sample_id} ({g})" if g else str(sample_id)
