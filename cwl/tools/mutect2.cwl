cwlVersion: v1.1
class: CommandLineTool
baseCommand: [gatk4, Mutect2]

label: Runs MuTect2 to find SNVs and indels on genomic data.

doc: |-
  MuTect2 Call somatic short mutations via local assembly of haplotypes. Short
  mutations include single nucleotide variant (SNVs) and insertion and deletion
  (indel) alterations.

requirements:
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}

hints:
  DockerRequirement:
    dockerPull: demichelislab/gatk4:latest

inputs:
  bam_file_normal:
    doc: The BAM file for the normal sample.
    type: File
    secondaryFiles: [^.bai, .bai]
    inputBinding:
      prefix: "--input"
  bam_file_tumor:
    doc: The BAM file for the tumor sample.
    type: File
    secondaryFiles: [^.bai, .bai]
    inputBinding:
      prefix: "--input"
  normal_sample_name:
    doc: The name of the normal sample.
    type: string
    inputBinding:
      prefix: "--normal-sample"
  reference_genome_fasta_file:
    doc: The file containing the reference genome in FASTA format.
    type: File
    secondaryFiles: [^.fai, .fai, ^.dict, .dict]
    inputBinding:
      prefix: "--reference"
  kit_target_interval_file:
    doc: |-
      The interval list file containing the regions captured by the capture kit.
    type: File
    inputBinding:
      prefix: "--intervals"
  variants_output_filename:
    doc: The name of the file where mutect2 will list the called variants.
    type: string?
    default: "mutect2.vcf"
    inputBinding:
      prefix: "--output"
  log_to_file:
    doc: |-
      If true, the output generated by the tool will be redirected to a file.
      Otherwise the output will be printed on the output.
    type: boolean
    default: true
  redirect_stdout_to_stderr:
    doc: |-
      If true, it includes the stderr output along with the stdout in the log
      file.
    type: boolean
    default: true
  log_filename:
    doc: The name of the output file that will contain the output.
    type: string
    default: "mutect2.log"

arguments:
  - valueFrom: "$(inputs.log_to_file ? '2> ' + inputs.log_filename + (inputs.redirect_stdout_to_stderr ? ' 1>&2' : '') : '')"
    shellQuote: false
    position: 99999

outputs:
  output:
    doc: The file containing the raw variants called by MuTect2.
    type: File?
    outputBinding:
      glob: $(inputs.variants_output_filename)
    secondaryFiles: [^.stats, .stats, ^.idx, .idx]
  log_file:
    doc: |-
      The log file, if enabled, that captures the output produced by the tool.
    type: File?
    outputBinding:
      glob: $(inputs.log_filename)
