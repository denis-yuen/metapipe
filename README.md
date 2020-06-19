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
Forward and reverse are determined by looking at the lexicographic order of the file's path: forward < reverse.
Note that the quotes are compulsory if the glob contains a `*`.

Note: by default the results appear in the directory where `nextflow run` is executed. To cheange this location, use `--exportDir`.

Some useful options:
- `--paramName <paramValue>...`: to provide parameters (the list of parameters is available in [main.nf](main.nf))
- `-c <configFile>`: to provide config file (overlayed on top of [nextflow.config](nextflow.config))
- `-resume`: to use cached results
- `-with-trace`: to generate a trace (text)
- `-N <email_address>`: to send an email when workflow execution ends


## Configuration

The workflow is provided with a default configuration which is sufficient to run Metapipe locally with the input files located in the [test](test) folder.
To be able to run Metapipe with larger datasets locally, or to run Metapipe on other executors (SLURM, Kubernetes, ...), a configuration file can optionally be provided
the `-c path/to/configFile` option to `nextflow run`.

Assuming that Metapipe is to be executed on the machine where `nextflow run` is being run (local executor), the configuration file may look like this:
```
executor {
  cpus = 8
  memory = '48 GB'
  //queueSize = 1
}

process {
  memory = '10 GB'
  withLabel: 'assembly' {
    cpus = 4
  }
  withName: 'Megahit' {
    cpus = 8
  }
}
```

### Executor

The `executor` section specifies properties of the execution environment such as:
- `cpus`: maximum number of CPUs available to run tasks (default: unlimited)
- `memory`: maximum amount of memory available to run tasks (default: unlimited)
- `queueSize`: maximum number of simultaneous tasks (default: unlimited)
- other properties can be found [here](https://www.nextflow.io/docs/latest/config.html#scope-executor).

Note: when using local executor, in case of warning: `WARNING: Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.`,
the limits will not be respected and may result in slow execution due to too many tasks attempting to run in parallel.
Please follow [these instructions](https://www.serverlab.ca/tutorials/containers/docker/how-to-limit-memory-and-cpu-for-docker-containers/).

### Process

The `process` section let us adjust some task-level properties such as:
- `cpus`: maximum number of CPUs available to run **one** task (default: 1)
- `memory`: maximum number of CPUs available to run **one** task (default: '1 GB')
- other properties can be found [here](https://www.nextflow.io/docs/latest/process.html#directives).

In the example configuration given above:
- any instance of the Megahit task will run with 8 CPUs and 10 GB memory
- any other task tagged with `assembly` will run with 4 CPUs and 10 GB memory
- any other task will run with 1 CPUs and 10 GB memory

### Advanced configuration

Please see [here](https://www.nextflow.io/docs/latest/config.html).