process Maxbin {
  //echo true

  container 'registry.gitlab.com/uit-sfb/genomic-tools/maxbin:2.2.7'

  input:
    path contigs, stageAs: 'in/*'
    path coverage, stageAs: 'in/*'

  output:
    path 'out/bin.*.fasta', emit: bins

  shell:
    '''
    set +u
    tail -n +2 !{coverage} | cut -f1,2 > /tmp/abundance_contigs.txt
    mkdir -p out
    /app/maxbin/run_MaxBin.pl -thread $MK_CPU_INT -contig !{contigs} -abund /tmp/abundance_contigs.txt -out out/bin
    '''
}