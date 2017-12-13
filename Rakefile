require_relative "ntt_facilities"
require_relative "iij_mio"
require_relative "tokyo_gas"

desc "import bills"
task :import_bills do
  ntt = NTT.new
  ntt.login
  ntt.update_from_sheet
  ntt.quit

  iij = IIJ_MIO.new
  iij.login
  iij.update_from_sheet
  iij.quit

  tg = TOKYO_GAS.new
  tg.login
  tg.update_from_sheet
  tg.quit
end
