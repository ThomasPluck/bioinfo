workflow evaluate_deep_variant{

    File ground_truth_bed
    File ground_truth_vcf
    File reference_fa_gz
    File uncompressed_ref
    File alignment_bam
    File model_dir
    File output_dir
    File example_dir

    call make_examples {
        input:
            alignment_bam = alignment_bam,
            reference_fa_gz = reference_fa_gz,
            example_dir = example_dir
    }

    call call_variants {
        input:
            example_dir = example_dir,
            model_dir = model_dir
    }

    call postprocess {
        input:
             reference_fa_gz = reference_fa_gz,
             example_dir = example_dir,
             output_dir = output_dir
    }

    call evaluate_vcf {
        input:
            ground_truth_vcf = ground_truth_vcf,
            predicted_vcf = find_variants.predicted_vcf,
            ground_truth_bed = ground_truth_bed,
            uncompressed_ref = uncompressed_ref,
            output_dir = output_dir
    }

    output {
        File out = output_dir + "evaluate_vcf.out"
    }
}

task make_examples{

    File alignment_bam
    File reference_fa_gz
    File example_dir

    command {
        /opt/deepvariant/bin/make_examples \
            --mode calling \
            --ref ${reference_fa_gz}/ucsc.hg19.chr20.unittest.fasta.gz \
            --reads ${alignment_bam} \
            --examples ${example_dir}/output.examples.tfrecord
    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File out = example_dir+"output.examples.tfrecord"
    }
}

task call_variants{
    
    File example_dir
    File model_dir

    command {
        
        /opt/deepvariant/bin/call_variants \
            --outfile ${example_dir}/call_variants_output.tfrecord \
            --examples ${example_dir}/output.examples.tfrecord \
            --checkpoint ${model_dir}/model.cpkt
    }

    runtime {
        docker: "grc.io/deepvariant-docker/deepvariant"
    }

    output {
        File out = 
    }
}

task postprocess {
    
    File reference_fa_gz
    File example_dir
    File output_dir

    command {
        /opt/deepvariant/bin/postprocess_variants \
            --ref ${reference_fa_gz}/ucsc.hg19.chr20.unittest.fasta.gz \
            --infile ${example_dir}/call_variants_output.tfrecord \
            --outfile ${output_dir}/output.vcf
    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File outfile = output_dir+"output.vcf"
    }
}
        
task evaluate_vcf{
    
    File ground_truth_vcf
    File predicted_vcf
    File ground_truth_bed
    File uncompressed_ref
    File output_dir

    command {

        "${ground_truth_vcf}" \
        "${predicted_vcf}" \
        -f "${ground_truth_bed}" \
        -r "${uncompressed_ref}" \
        -o "eval.output"

    }

    runtime {
        docker: "pkrusche/hap.py"
    }

    output {
        File out = output_dir+"eval.output"
    }
}
