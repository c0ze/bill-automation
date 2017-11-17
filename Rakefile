require_relative "ntt_facilities"
require_relative "iij_mio"

desc "import bills"
task :import_bills do
  ntt = NTT.new
  ntt.login
  ntt.update_from_sheet
  ntt.quit

  iij = IIJ_MIO.new
  iij.login
  # iij.download_all
  iij.update_from_sheet
  iij.quit
end
