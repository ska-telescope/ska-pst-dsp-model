function all_sgcht ()

signals = { 'frequency_comb', 'square_wave' };

configs = { 'mid', 'low', 'low_psi' };

for cfg = configs

    combs = { '', 'coarse' };

    for sig = signals

        sgcht(signal=sig{1});

        for cmb = combs

            critical = [ false ];

            for twostg = [ false, true ]

                for inv = [ false, true ]

                    for crit = critical

                        fprintf ('sig=%s cmb=%s cfg=%s 2stg=%d inv=%d crt=%d\n', ...
                             sig{1}, cmb{1}, cfg{1}, twostg, inv, critical);

                        sgcht(signal=sig{1}, comb=cmb{1}, cfg=cfg{1}, ...
                            two_stage=twostg, invert=inv, critical=crit);

                    end % loop over critical sampling

                end % loop over PFB inversion

                % when twostg = true on next loop, 
                % then critical = true is possible
                critical = [ false, true ];

            end % loop over stages

        end % loop over combs

        % combs apply only to frequency_comb
        combs = {''};

    end % loop over signals

end % loop over PFB configurations
