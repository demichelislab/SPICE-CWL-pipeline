cwlVersion: v1.1
class: CommandLineTool
baseCommand: [pipeline_utils, merge_vep_snv_coverage]

label: Merges SNV coverage data with VEP annotation

doc: |-
  Script that allows to merge a file (in tabular format) of variants annotated
  by VEP with the coverage information of the tumor and normal samples. In
  particular the script will add the coverage of reference and alternative bases
  and the allelic fractions at SNV positions in normal and tumor samples.

requirements:
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}

hints:
  DockerRequirement:
    dockerPull: demichelislab/pipeline_utils:latest

inputs:
  vep_annotated_variants:
    doc: The file containing the variants annotated by VEP.
    type: File
    inputBinding:
      position: 1
  snvs_pileup_normal:
    doc: The file containing the pileup of the SNPs for the normal sample.
    type: File
    inputBinding:
      position: 2
  snvs_pileup_tumor:
    doc: The file containing the pileup of the SNPs for the tumor sample.
    type: File
    inputBinding:
      position: 3
  output_filename:
    doc: The name of the file where the variants with coverage will be saved.
    type: string?
    default: "vep_and_coverage.txt"
    inputBinding:
      prefix: "--output_filename"
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
    default: "merge_vep_snv_coverage.log"

outputs:
  output:
    doc: The variant file with coverage information added.
    type: File?
    outputBinding:
      glob: $(inputs.output_filename)
  log_file:
      doc: |-
        The log file, if enabled, that captures the output produced by the tool.
    type: File?
    outputBinding:
      glob: $(inputs.log_filename)

arguments:
  - valueFrom: $(runtime.outdir)
    position: 4
  - valueFrom: "$(inputs.log_to_file ? '2> ' + inputs.log_filename + (inputs.redirect_stdout_to_stderr ? ' 1>&2' : '') : '')"
    shellQuote: false
    position: 99999

