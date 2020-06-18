# Metapipe

[Metapipe](https://gitlab.com/uit-sfb/metapipe) is a workflow for analysis and annotation of metagenomic samples,
providing insight into phylogenetic diversity, as well as metabolic and functional properties of environmental communities.

As illustrated in the diagram below, the workflow is divided into four modules:
  - filtering and assembly
  - taxonomic classification
  - functional assignment
  - binning

![Metapipe workflow](source/images/schematics/agnostic_metapipe_bioinf_pipeline.png)  
*Metapipe workflow schematic*

The workflow was [designed](https://munin.uit.no/handle/10037/11180) to leverage the most modern tools to 
ensure both quality outputs and efficient resource usage.

In addition, it is now clear that the quality of the reference databases plays a role at least as important
as the tools themselves when it comes to output quality and execution speed.
This is why META-pipe makes use of *plugged-in* reference databases gathered into profiles.
For instance, the *Marine* profile uses exclusively the high quality [MAR databases](https://mmp.sfb.uit.no/databases/) as reference databases.

<div align="center">
  ![Metapipe profiles](source/images/schematics/profiles.png)  
</div>
*Metapipe profiles*

## Getting started

### Requirements

- [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) ([requirements](https://www.nextflow.io/docs/latest/getstarted.html#requirements))
- [Docker](https://docs.docker.com/get-docker/)

### Executing the workflow

```bash
#Optional, only to fetch changes from repository
nextflow pull http://gitlab.com/uit-sfb/metapipe
nextflow run http://gitlab.com/uit-sfb/metapipe --reads "/path/to/{r1,r2}.fastq*" [options]
```

Note: the `--reads` parameters is a glob matching both forward and reverse FASTQ files (`.gz` are also accepted).
Forward and reverse are determined by looking at the lexicographic order of the files path: forward < reverse.
Note that the quotes are compulsory if the glob contains a `*`.

Some useful options:
- `--paramName <paramValue>...`: to provide parameters (the list of parameters is available in [main.nf](main.nf))
- `-c <configFile>`: to provide config file (overlayed on top of [nextflow.config](nextflow.config))
- `-resume`: to use cached results
- `-with-trace`: to generate a trace (text)
- `-N <email_address>`: to send an email when workflow execution ends

#### Debugging

Clone the repo, then:
```bash
mkdir -p target && cd target
nextflow run .. [options]
```

#### Advanced configuration

In case of warning: `WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.`:
[see here](https://www.serverlab.ca/tutorials/containers/docker/how-to-limit-memory-and-cpu-for-docker-containers/).
