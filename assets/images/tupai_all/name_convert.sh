for name in `ls *.gif`; do
  converted=${name/_ji_e/_ji1}
  test ${name} != ${converted} && mv ${name} ${converted}

  converted=${name/_ji_s/_ji2}
  test ${name} != ${converted} && mv ${name} ${converted}

  converted=${name/_ji_w/_ji3}
  test ${name} != ${converted} && mv ${name} ${converted}

  converted=${name/_ji_n/_ji4}
  test ${name} != ${converted} && mv ${name} ${converted}

  converted=${name/_no/_ji5}
  test ${name} != ${converted} && mv ${name} ${converted}

  converted=${name/_ji_h/_ji6}
  test ${name} != ${converted} && mv ${name} ${converted}

  converted=${name/_ji_c/_ji7}
  test ${name} != ${converted} && mv ${name} ${converted}

done
