functions{
  vector WHITE_XYZ(){return [0.95047, 1.0, 1.08883]';}
  real CIELAB_D(){return (6.0 / 29.0);}
  real CIELAB_M(){return pow(29.0 / 6.0, 2.0) / 3.0;}
  real CIELAB_C(){return 4.0 / 29.0;}
  real CIELAB_A(){return 3.0;}
  real CIELAB_RECIP_A(){return 1.0 / CIELAB_A();}
  real CIELAB_POW_D_A(){return pow(CIELAB_D(), CIELAB_A());}
  matrix CIELAB_MATRIX(){return [[0.0, 1.16, 0.0 ],
                                 [5.0, -5.0, 0.0],
                                 [0.0, 2.0, -2.0 ]];}
  matrix CIELAB_MATRIX_INV(){return [[0.86206897, 0.2, 0.0],
                                     [0.86206897, 0.0, 0.0],
                                     [0.86206897, 0.0, -0.5]];}
  real CIELAB_OFFSET(){return -0.16;}
  
  
  
  real cielab_from_linear(real x) {
      return x <= CIELAB_POW_D_A() ?
             CIELAB_M() * x + CIELAB_C() :
             pow(x, CIELAB_RECIP_A());
  }
  
  
  real cielab_to_linear(real y) {
      return y <= CIELAB_D() ?
             (y - CIELAB_C()) / CIELAB_M() :
             pow(y, CIELAB_A());
  }
  
  
  vector cielab_to_xyz(vector lab) {
      vector[3] ret_lab;
      vector[3] xyz;
      
      ret_lab = lab;
      ret_lab[1] -= CIELAB_OFFSET();
      xyz = CIELAB_MATRIX_INV() * ret_lab;
      xyz[1] = cielab_to_linear(xyz[1]) * WHITE_XYZ()[1];
      xyz[2] = cielab_to_linear(xyz[2]) * WHITE_XYZ()[2];
      xyz[3] = cielab_to_linear(xyz[3]) * WHITE_XYZ()[3];
      return xyz;
  }

  
  vector cielab_from_xyz(vector xyz) {
      vector[3] fxyz;
      vector[3] lab;
      
      fxyz = [cielab_from_linear(xyz[1] / WHITE_XYZ()[1]),
              cielab_from_linear(xyz[2] / WHITE_XYZ()[2]),
              cielab_from_linear(xyz[3] / WHITE_XYZ()[3])]';
      lab = CIELAB_MATRIX() * fxyz;
      lab[1] += CIELAB_OFFSET();
      return lab;
  }
  

  real SRGB_D(){return 0.04045;}
  real SRGB_M(){return 12.92;}
  real SRGB_A(){return 2.4;}
  real SRGB_K(){return 0.055;}
  matrix SRGB_MATRIX(){return [[3.2406, -1.5372, -0.4986],
                               [-0.9689, 1.8758, 0.0415],
                               [0.0557, -0.204 , 1.057]];}
  matrix SRGB_MATRIX_INV(){return [[0.41239559, 0.35758343, 0.18049265],
                                   [0.21258623, 0.7151703 , 0.0722005],
                                   [0.01929722, 0.11918386, 0.95049713]];}
  
  
  vector srgb_from_linear(real x){
      real ret_x = x;
      real bad = 0.0;
      
      if (ret_x > 1.0) {
          ret_x = 1.0;
          bad = 1.0;
      } else if (ret_x < 0.0) {
          ret_x = 0.0;
          bad = 1.0;
      }
      ret_x = ret_x <= SRGB_D() / SRGB_M() ?
              SRGB_M() * ret_x :
              (1 + SRGB_K()) * pow(ret_x, 1 / SRGB_A()) - SRGB_K();
      return [ret_x, bad]';
  }
  
  
  vector srgb_to_linear(real y) {
      real ret_y = y;
      real bad = 0.0;
      
      if (ret_y > 1.0) {
          ret_y = 1.0;
      } else if (ret_y < 0.0) {
          ret_y = 0.0;
      }
      ret_y = ret_y <= SRGB_D() ?
              ret_y / SRGB_M() :
              pow((ret_y + SRGB_K()) / (1 + SRGB_K()), SRGB_A());
      
      return [ret_y, bad]';
  }

  
  vector srgb_from_xyz(vector xyz) {
      real bad = 0.0;
      vector[3] rgb;
      vector[4] ret;
      vector[2] cur;
      
      rgb = SRGB_MATRIX() * xyz;
      cur = srgb_from_linear(rgb[1]);
      rgb[1] = cur[1]; 
      bad = max([bad, cur[2]]);
      
      cur = srgb_from_linear(rgb[2]);
      rgb[2] = cur[1]; 
      bad = max([bad, cur[2]]);
      
      cur = srgb_from_linear(rgb[3]);
      rgb[3] = cur[1]; 
      bad = max([bad, cur[2]]);

      ret[1:3] = rgb;
      ret[4] = bad;
      return ret;
  }
  
  
  vector srgb_to_xyz(vector rgb) {
      return SRGB_MATRIX_INV() * [srgb_to_linear(rgb[1])[1],
                                  srgb_to_linear(rgb[2])[1],
                                  srgb_to_linear(rgb[3])[1]]';
  }


  vector srgb_to_cielab(vector rgb) {
      vector[4] ret;
      vector[3] xyz = srgb_to_xyz(rgb);
      vector[3] lab = cielab_from_xyz(xyz);
      
      ret[1:3] = lab;
      ret[4] = 1.0;
      return ret;
  }
  
  
  vector cielab_to_srgb(vector lab){
      vector[3] xyz = cielab_to_xyz(lab);
      vector[3] rgb = srgb_from_xyz(xyz)[1:3];
      real bad = srgb_from_xyz(xyz)[4];
      vector[4] ret;
      
      ret[1:3] = rgb;
      ret[4] = 1.0 - bad;
      return ret;
  } 
  
  
  real mu_uniform_prior(vector lab){
    real in_gamut = cielab_to_srgb(lab)[4];
    if(in_gamut == 1.0){
      return 0;
    }
    else{
      reject("Color out of RGB color space: prior is zero.");
      return negative_infinity();
    }
  } 
}


data{
  int<lower=1> n;                                 // total number of data points
  matrix<lower=0, upper=255>[n, 3] RGB_data;      // data of RGB data points
}


transformed data{
  vector[3] CIELAB_data[n];
  for(i in 1:n){
    vector[3] RGB_vec = to_vector(1.0 * RGB_data[i, ] / 255.0);
    CIELAB_data[i] = srgb_to_cielab(RGB_vec)[1:3];
  }
}


parameters{
  vector[3] mu;                 // mean
  vector<lower=0>[3] sigma;     // variance vector
  corr_matrix[3] correlation;   // correlation matrix
}


transformed parameters{
  // covariance matrix
  cov_matrix[3] covariance = diag_matrix(sqrt(sigma)) * 
                             correlation * diag_matrix(sqrt(sigma));
} 


model{
  // priors
  target += mu_uniform_prior(mu);
  sigma ~ cauchy(0, 10);
  correlation ~ lkj_corr(2.0);

  // model
  CIELAB_data ~ multi_normal(mu, covariance);
}

generated quantities{
  vector[3] mu_RGB; 
  vector[n] log_lik;
  
  mu_RGB = cielab_to_srgb(mu) * 255;
  for (i in 1:n) {
    log_lik[i] = multi_normal_lpdf(CIELAB_data[i] | mu, covariance);
  }
}