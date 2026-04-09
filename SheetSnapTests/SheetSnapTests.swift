import XCTest
@testable import SheetSnap

final class SheetSnapTests: XCTestCase {
    func testTableTSVNormalizeDropsLeadingCaptionForMultiColumnTable() {
        let raw = """
        Table 4: table 3 with column headers added
        Role\tActor
        Main character\tDaniel Radcliffe
        """

        let normalized = TableTSV.normalize(raw)

        XCTAssertEqual(
            normalized,
            """
            Role\tActor
            Main character\tDaniel Radcliffe
            """
        )
    }

    func testTableTSVNormalizeKeepsSingleColumnTable() {
        let raw = """
        Single column item
        Another item
        """

        XCTAssertEqual(TableTSV.normalize(raw), raw)
    }

    func testDocTagsParserConvertsOTSLToTSV() {
        let docTags = """
        <otsl><ched>Role<ched>Actor<nl/><fcel>Main character<fcel>Daniel Radcliffe<nl/><fcel>Sidekick 1<fcel>Rupert Grint<nl/></otsl>
        """

        let tsv = DocTagsParser.toTSV(docTags)

        XCTAssertEqual(
            tsv,
            """
            Role\tActor
            Main character\tDaniel Radcliffe
            Sidekick 1\tRupert Grint
            """
        )
    }

    func testDocTagsParserFallsBackToPipeTables() {
        let raw = """
        Role | Actor
        Main character | Daniel Radcliffe
        Sidekick 1 | Rupert Grint
        """

        let tsv = DocTagsParser.toTSV(raw)

        XCTAssertEqual(
            tsv,
            """
            Role\tActor
            Main character\tDaniel Radcliffe
            Sidekick 1\tRupert Grint
            """
        )
    }

    func testTableTSVRejectsSingleColumnTextBlob() {
        let raw = """
        This is just OCR text
        not a structured table
        """

        XCTAssertFalse(TableTSV.isLikelyTable(raw))
    }

    func testModelAssetUnavailableErrorMessageIsProductFacing() {
        XCTAssertEqual(
            SheetSnapError.modelAssetUnavailable.errorDescription,
            "The table model is not available on this Mac yet. Please try again after the app finishes downloading its Apple-hosted assets."
        )
    }
}
