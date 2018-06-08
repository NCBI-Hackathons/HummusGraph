# Scripts

This directory is a collection of scripts used for this project. Below is a brief summary of what each script does.

---

### Summary

- `minimap2_full_genome-asm5.sh` uses Minimap2 to align an assembly.fa file to a reference.fa file and outputs a SAM file. This script uses default mapping parameters (asm5).
- `index_reference.sh` uses SAMTools to index the reference.fa file. SAMTools SAM to BAM conversion requires an indexed reference.fa file.
- `sam_processing.sh` uses SAMTools to convert file from SAM to BAM and generates read alignment statistics. This is useful when figuring out appropriate mapping parameters for different organisms.
