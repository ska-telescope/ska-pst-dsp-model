function all_sgcht ()

signals = { 'frequency_comb', 'square_wave' };

configs = { 'low', 'mid', 'low_psi' };

for cfg = configs

    combs = { '', 'coarse' };

    for sig = signals

        sgcht(signal=sig{1});

        for twostg = [ false, true ]

            for inv = [ false, true ]

                for cmb = combs

                    fprintf ('sig=%s cmb=%s cfg=%s 2stg=%d inv=%d\n', ...
                             sig{1}, cmb{1}, cfg{1}, twostg, inv);

                    sgcht(signal=sig{1}, comb=cmb{1}, cfg=cfg{1}, ...
                            two_stage=twostg, invert=inv);

                end
            end
        end

        % combs apply only to frequency_comb
        combs = {''};
    end
end
