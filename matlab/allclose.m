function res=allclose(a, b, atol_, rtol_)
  atol = 1e-5;
  rtol = 1e-8;

  if exist('atol_', 'var')
    atol = atol_;
  end

  if exist('rtol_', 'var')
    rtol = rtol_;
  end
  
  res = all( abs(a(:)-b(:)) <= atol+rtol*abs(b(:)) )
end
