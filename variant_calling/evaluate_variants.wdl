workflow evaluate_deep_variant{

    File input_dir
    File model_dir
    File output_dir
    File example_dir

    call make_examples {
        input:
            input_dir = input_dir,
            example_dir = example_dir
    }

    call call_variants {
        input:
            example_dir = example_dir,
            model_dir = model_dir,
            input_file = make_examples.out
    }

    call postprocess {
        input:
             input_dir = input_dir,
             example_dir = example_dir,
             output_dir = output_dir,
             input_file = call_variants.out
    }

    call evaluate_vcf {
        input:
            input_dir = input_dir,
            predicted_vcf = postprocess.out,
            output_dir = output_dir
    }

    output {
        File out = evaluate_vcf.out
    }
}

task make_examples{

    File input_dir
    File example_dir

    command {
        /opt/deepvariant/bin/make_examples \
            --mode calling \
            --ref ${input_dir}/ucsc.hg19.chr20.unittest.fasta.gz \
            --reads ${input_dir}/NA12878_S1.chr20.10_10p1mb.bam \
            --examples output.examples.tfrecord \
            --regions "chr20:10,000,000-10,010,000"
    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File out = "output.examples.tfrecord"
    }
}

task call_variants{
    
    File example_dir
    File model_dir
    File input_file

    command {
        /opt/deepvariant/bin/call_variants \
            --outfile call_variants_output.tfrecord \
            --examples ${input_file} \
            --checkpoint ${model_dir}/model.cpkt
    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File out = "call_variants_output.tfrecord"
    }
}

task postprocess {
    
    File input_dir
    File example_dir
    File output_dir
    File input_file

    command {
        /opt/deepvariant/bin/postprocess_variants \
            --ref ${input_dir}/ucsc.hg19.chr20.unittest.fasta.gz \
            --infile ${input_file} \
            --outfile ${output_dir}/output.vcf
    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File out = "output1.vcf"
    }
}
        
task evaluate_vcf{
    
    File input_dir
    File predicted_vcf
    File output_dir

    command {

        "${input_dir}/test_nist.b37_chr20_100kbp_at_10mb.vcf.gz" \
        "${predicted_vcf}" \
        -f "${input_dir}/test_nist.b37_chr20_100kbp_at_10mb.bed" \
        -r "${input_dir}/ucsc.hg19.chr20.unittest.fasta" \
        -o "eval.output"

    }

    runtime {
        docker: "pkrusche/hap.py"
    }

    output {
        File out = output_dir+"eval.output"
    }
}
