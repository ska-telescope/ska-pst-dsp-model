function test_sgcht_one (cfg_, sig_)

fail = 0;

res = sgcht(signal=sig_, test=true);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail with no channelisation \n', sig_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail with %s channeliser \n', sig_, cfg_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_, invert=true);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail after inverting %s channeliser \n', sig_, cfg_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_, two_stage=true);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail after two-stage %s channeliser \n', sig_, cfg_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_, two_stage=true, invert=true);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail after inverting second-stage %s channeliser \n', sig_, cfg_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_, two_stage=true, critical=true);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail after critically-sampled second-stage %s channeliser \n', sig_, cfg_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_, two_stage=true, critical=true, invert=true);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail after inverting critically-sampled second-stage %s channeliser \n', sig_, cfg_);
end

res = sgcht(signal=sig_, test=true, cfg=cfg_, two_stage=true, critical=true, invert=true, combine=16);
if (res ~= 0)
    fail = fail + 1;
    fprintf ('%s: fail after combining 16 coarse channels while inverting critically-sampled second-stage %s channeliser \n', sig_, cfg_);
end

if (fail == 0)
    fprintf ('%s: all tests passed', sig_)
else
    fprintf ('%s: %d tests failed', sig_, fail)
end
