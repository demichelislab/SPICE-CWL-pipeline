cwlVersion: v1.1
class: CommandLineTool
baseCommand: [spia]

label: Computes genotype distance between two or more samples.

doc: |-
  SPIA allows for the verification of two or more DNA samples deriving from the
  same or different individuals.

requirements:
  SchemaDefRequirement:
    types:
      - $import: "../types/spia_output_map.yaml"
  ShellCommandRequirement: {}
  InlineJavascriptRequirement: {}
  LoadListingRequirement:
    loadListing: deep_listing
  InitialWorkDirRequirement:
    listing: |
      ${
        return [
          {
            class: "Directory",
            basename: inputs.output_directory_name,
            listing: [
              {
                class: "Directory",
                basename: "cfg",
                listing: [
                  {
                    class: "File",
                    basename: "vcf_files.txt",
                    contents: inputs.genotype_vcf_files.map(function (e) { return "spia/genotypes/" + e.basename; }).join("\n")
                  },
                  {
                    class: "File",
                    basename: "spia.cfg",
                    contents: [
                      'Pmm                <- 0.1',
                      'nsigma             <- 2',
                      'Pmm_nonM           <- 0.6',
                      'nsigma_nonM        <- 5',
                      'PercValidCall      <- 0.7',
                      'verbose            <- FALSE',
                      'print_on_screen    <- FALSE',
                      'vcfFileList        <- ' + '"' + inputs.output_directory_name + '/cfg/vcf_files.txt"',
                      'outSPIAtable_file  <- ' + '"' + inputs.output_directory_name + '/' + inputs.output_table_filename + '"',
                      'saveSPIAplot       <- ' + (inputs.plot_filename !== null).toString().toUpperCase(),
                      'SPIAplot_file      <- ' + '"' + (inputs.plot_filename === null ? '' : inputs.output_directory_name + '/' + inputs.plot_filename) + '"',
                      'saveGenotype       <- FALSE',
                      'genotypeTable_file <- ""'
                    ].join("\n")
                  }
                ],
                writable: true
              },
              {
                class: "Directory",
                basename: "genotypes",
                listing: inputs.genotype_vcf_files,
                writable: true
              }
            ],
            writable: true
          }
        ];
      }

hints:
  DockerRequirement:
    dockerPull: demichelislab/spia:latest


inputs:
  genotype_vcf_files:
    doc: |-
      The files containing the genotypes of the samples to be analyzed. SPIA 
      will compare all possible pairings of the samples that are provided in
      this list.
    type: File[]
  output_directory_name:
    doc: The name of the folder where the SPIA outputs will be written.
    type: string?
    default: "spia"
  output_table_filename:
    doc: The name of the file where the SPIA output table will be written.
    type: string?
    default: "spia.tsv"
  plot_filename:
    doc: |-
      The name of the file that will contain the SPIA plot. Only when this
      parameter is provided the report will be generated.
    type: string?
  log_to_file:
    doc: |-
      If true, the output generated by the tool will be redirected to a
      file. Otherwise the output will be printed on the output.
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
    default: "spia.log"

outputs:
  output:
    doc: The output directory produced by SPIA.
    type: Directory?
    outputBinding:
      glob: "$(inputs.output_directory_name)"
  output_map:
    doc: |-
      A data structure that will allow easy access to the various outputs
      generated by SPIA.
    type: out_map:spia_output_map?
    outputBinding:
      glob: "$(inputs.output_directory_name)"
      outputEval: |
        ${
          var endswith_filt_fun = function (filt) { return function (ff) { return ff.basename.endsWith(filt) }; },
              isclass_filt_fun  = function (class_match) { return function (ff) { return ff.class === class_match }; },
              files_result      = self[0].listing.filter(isclass_filt_fun("File")),
              content_cfg       = self[0].listing.filter(endswith_filt_fun("cfg"))[0].listing;
          var result            = {
            table:         files_result.filter(endswith_filt_fun(inputs.output_table_filename))[0],
            configuration: content_cfg.filter(endswith_filt_fun("spia.cfg"))[0],
            vcf_list:      content_cfg.filter(endswith_filt_fun("vcf_files.txt"))[0],
            genotypes:     self[0].listing.filter(endswith_filt_fun("genotypes"))[0].listing
          };
          if (inputs.plot_filename != null) {
            result.report_pdf = files_result.filter(endswith_filt_fun(inputs.plot_filename))[0];
          }
          return result;
        }
  log_file:
    doc: |-
      The log file, if enabled, that captures the output produced by the tool.
    type: File?
    outputBinding:
      glob: $(inputs.log_filename)

arguments:
  - valueFrom: $(inputs.output_directory_name + "/cfg/spia.cfg")
    position: 1
  - valueFrom: "$(inputs.log_to_file ? '2> ' + inputs.log_filename + (inputs.redirect_stdout_to_stderr ? ' 1>&2' : '') : '')"
    shellQuote: false
    position: 99999

$namespaces:
  out_map: "../types/spia_output_map.yaml#"