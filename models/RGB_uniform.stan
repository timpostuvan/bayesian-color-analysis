data{
  int<lower=1> n;                                              // total number of data points
  matrix<lower=0, upper=255>[n, 3] RGB_data_raw;               // data of RGB data points
}


transformed data{
  vector[3] RGB_data[n];
  for(i in 1:n){
    vector[3] RGB_vec = to_vector(1.0 * RGB_data_raw[i, ] / 255.0);
    RGB_data[i] = RGB_vec;
  }
}


parameters {
  vector<lower=0, upper=1>[3] mu;    // mean
  vector<lower=0>[3] sigma;          // variance vector
}

model{
  // priors
  mu ~ uniform(0, 1);
  sigma ~ cauchy(0, 10);

  // model
  RGB_data ~ multi_normal(mu, diag_matrix(sigma));
}

generated quantities{
  vector[3] mu_RGB; 
  vector[n] log_lik;
  
  mu_RGB = mu * 255;
  for (i in 1:n) {
    log_lik[i] = multi_normal_lpdf(RGB_data[i] | mu, diag_matrix(sigma));
  }
}