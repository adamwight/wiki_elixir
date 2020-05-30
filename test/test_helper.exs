ExUnit.start()

Mox.defmock(Wiki.Tests.HTTPoisonMock, for: HTTPoison.Base)
Mox.defmock(Wiki.Tests.TeslaAdapterMock, for: Tesla.Adapter)
