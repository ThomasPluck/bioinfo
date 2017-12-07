workflow evaluate_deep_variant{

    File ground_truth_bed
    File ground_truth_vcf
    File reference_fa_gz
    File uncompressed_ref
    File alignment_bam
    File model_cpkt
    File output_dir
    File example_dir

    call find_variants {
        input:
            alignment_bam = alignment_bam,
            reference_fa_gz = reference_fa_gz,
            model_cpkt = model_cpkt,
            output_dir = output_dir,
            example_dir = example_dir
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

task find_variants{

    File alignment_bam
    File reference_fa_gz
    File model_cpkt
    File output_dir
    File example_dir

    command {

        /opt/deepvariant/bin/make_examples \
            --mode calling \
            --ref ${reference_fa_gz} \
            --reads ${alignment_bam} \
            --examples ${example_dir}/output.examples.tfrecord


        /opt/deepvariant/bin/call_variants \
            --outfile ${example_dir}call_variants_output.tfrecord \
            --examples ${example_dir}/output.examples.tfrecord \
            --checkpoint ${model_cpkt}/model.cpkt

        /opt/deepvariant/bin/postprocess_variants \
            --ref ${reference_fa_gz} \
            --infile ${example_dir}/call_variants_output.tfrecord \
            --outfile ${output_dir}/output.vcf

    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File predicted_vcf = output_dir+"output.vcf"
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
