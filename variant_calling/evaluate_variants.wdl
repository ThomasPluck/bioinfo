workflow evaluate_deep_variant{

    File ground_truth_bed
    File ground_truth_vcf
    File reference_fa_gz
    File uncompressed_ref
    File alignment_bam
    String model_cpkt
    String output

    call find_variants {
        input:
            alignment_bam = alignment_bam,
            reference_fa_gz = reference_fa_gz,
            model_cpkt = model_cpkt
    }

    call evaluate_vcf {
        input:
            ground_truth_vcf = ground_truth_vcf,
            predicted_vcf = find_variants.predicted_vcf,
            ground_truth_bed = ground_truth_bed,
            uncompressed_ref = uncompressed_ref 
    }

    output {
        File out = output + "evaluate_vcf.out"
    }
}

task find_variants{

    File alignment_bam
    File reference_fa_gz
    String model_cpkt
    String output

    command {

        ./opt/deepvariant/bin/make_examples \
            --mode calling \
            --ref ${reference_fa_gz} \
            --reads ${alignment_bam} \
            --examples output.examples.tfrecord \


        ./opt/deepvariant/bin/call_variants \
            --outfile call_variants_output.tfrecord \
            --examples output.examples.tfrecord \
            --checkpoint ${model_cpkt}+"model.cpkt"

        ./opt/deepvariant/bin/postprocess_variants \
            --ref ${reference_fa_gz} \
            --infile call_variants_output.tfrecord \
            --outfile ${output}+"output.vcf"

    }

    runtime {
        docker: "gcr.io/deepvariant-docker/deepvariant"
    }

    output {
        File predicted_vcf = ${output}"output.vcf"
    }
}

task evaluate_vcf{
    
    File ground_truth_vcf
    File predicted_vcf
    File ground_truth_bed
    File uncompressed_ref

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
        File out = ${output}"eval.output"
    }
}
