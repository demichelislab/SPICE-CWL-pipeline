cwlVersion: v1.1
class: Workflow

requirements:
  SchemaDefRequirement:
    types:
      - $import: "../types/tpes_output_map.yaml"
  SubworkflowFeatureRequirement: {}
  InlineJavascriptRequirement: {}
  StepInputExpressionRequirement: {}
  MultipleInputFeatureRequirement: {}

inputs:
  snvs_pileup:
    doc: The file containing the pileup of the SNVs of the tumor sample.
    type: File
  ploidy_table:
    doc: The ploidy table as is generated by CLONET
    type: File
  segfile:
    doc: The copy number segments.
    type: File
  sample_name:
    doc: The name of the sample that is passed in input.
    type: string
  plot_filename:
    doc: |-
      The name of the file that will contain the TPES plot. The report will be
      generated only when this parameter is provided.
    type: string?
  log_to_file:
    doc: |-
      If true, the output generated by each tool will be redirected to a file.
      Otherwise the output will be printed on the output.
    type: boolean
    default: true

outputs:
  output:
    doc: The output directory produced by TPES.
    type: Directory?
    outputSource: merge_output/output
  output_map:
    doc: |-
      A data structure that will allow easy access to the various outputs
      produced by TPES.
    type: out_map:tpes_output_map?
    outputSource: merge_output/output_map
  log_files:
    doc: |-
      The log file, if enabled, that captures the output produced by each tool.
    type: File[]?
    outputSource:
      - pileup_to_coverage/log_file
      - tpes/log_file

steps:
  pileup_to_coverage:
    doc: Computes the coverage of SNVs starting from the pileup.
    run: ../tools/pileup_to_coverage.cwl
    in:
      sample_name: sample_name
      snvs_pileup: snvs_pileup
      log_to_file: log_to_file
    out:
      - output
      - log_file
  ploidy_from_table:
    doc: Extracts the ploidy from the CLONET output.
    in:
      ploidy_table:
        source: ploidy_table
        loadContents: true
    out:
      - output
    run:
      class: ExpressionTool
      inputs:
        ploidy_table: File
      outputs:
        output: string
      expression: |
        ${
          var rows            = inputs.ploidy_table.contents.split("\n"),
              header          = rows[0].split("\t"),
              values          = rows[1].split("\t"),
              ploidy_position = header.indexOf("ploidy"),
              ploidy          = parseFloat(values[ploidy_position]);
          return {
            output: isNaN(ploidy) ? "NA" : ploidy.toString()
          };
        }
  tpes:
    doc: Runs TPES to estimate admixture from SNVs.
    run: ../tools/tpes.cwl
    in:
      sample_name: sample_name
      segfile: segfile
      snv_coverage_file: pileup_to_coverage/output
      ploidy: ploidy_from_table/output
      plot_filename: plot_filename
      log_to_file: log_to_file
    out:
      - output
      - output_map
      - log_file
  merge_output:
    doc: Merges outputs of each step in a single output port and output_map.
    in:
      pileup_to_coverage: pileup_to_coverage/output
      tpes: tpes/output
      tpes_output_map: tpes/output_map
    out:
      - output
      - output_map
    run:
      class: ExpressionTool
      requirements:
        LoadListingRequirement:
          loadListing: shallow_listing
      inputs:
        pileup_to_coverage: File?
        tpes: Directory?
        tpes_output_map: out_map:tpes_output_map?
      outputs:
        output: Directory?
        output_map: out_map:tpes_output_map?
      expression: |
        ${
          var output_directory = inputs.tpes,
              output_map       = inputs.tpes_output_map;
          delete output_directory['location'];
          output_directory.listing.push(inputs.pileup_to_coverage);
          output_map.snvs_coverage = inputs.pileup_to_coverage;
          return {
            output:     output_directory,
            output_map: output_map
          };
        }

$namespaces:
  out_map: "../types/tpes_output_map.yaml#"
