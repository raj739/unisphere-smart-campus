from app.data.vikram_programme_catalog import CATALOG


def test_vikram_programme_catalog_shape():
    assert len(CATALOG) == 43
    assert len({item["code"] for item in CATALOG}) == 43

    options = {
        item["code"]: len(item["specializations"])
        for item in CATALOG
    }
    assert options["PG-DIP"] == 28
    assert options["DIPLOMA"] == 29
    assert options["CERTIFICATE"] == 48
    assert options["PHD"] == 33
    assert sum(options.values()) == 315
