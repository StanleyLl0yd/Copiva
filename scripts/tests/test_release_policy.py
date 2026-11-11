import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from release_policy import build_authorized, publication_authorized


class PublicationAuthorizationTests(unittest.TestCase):
    def setUp(self):
        self.request = {
            "version": "0.0.2",
            "authorized_by": "StanleyLl0yd",
            "authorization_date": "2026-11-11",
            "publication": "github-release",
        }

    def testMatchingOwnerRequestAllowsOnlyItsExactVersion(self):
        self.assertTrue(publication_authorized(self.request, "0.0.2"))
        self.assertFalse(publication_authorized(self.request, "0.0.3"))

    def testMissingOrMalformedRequestsFailClosed(self):
        for request in [None, [], {}, "github-release"]:
            with self.subTest(request_type=type(request).__name__):
                self.assertFalse(publication_authorized(request, "0.0.2"))
        for key in self.request:
            request = copy.copy(self.request)
            del request[key]
            with self.subTest(missing=key):
                self.assertFalse(publication_authorized(request, "0.0.2"))

    def testDifferentActorPurposeAndInvalidDatesFailClosed(self):
        for key, value in [
            ("authorized_by", "synthetic-other-actor"),
            ("publication", "unrecognized-purpose"),
            ("authorization_date", "2026-99-99"),
            ("authorization_date", "20261111"),
            ("authorization_date", None),
        ]:
            request = {**self.request, key: value}
            with self.subTest(field=key, value=value):
                self.assertFalse(publication_authorized(request, "0.0.2"))

    def testBuildOnlyRequestConstructsArtifactsWithoutAuthorizingPublication(self):
        request = {**self.request, "publication": "actions-artifact"}
        self.assertTrue(build_authorized(request, "0.0.2"))
        self.assertFalse(publication_authorized(request, "0.0.2"))
        self.assertFalse(build_authorized(request, "0.0.3"))
        self.assertFalse(build_authorized({**request, "authorized_by": None}, "0.0.2"))

    def testQualifiedAndNoncanonicalVersionsFailClosedEvenWhenTheyMatch(self):
        for version in ["0.0.2-alpha", "0.0.2-m1", "00.0.2", "v0.0.2", "0.2", None]:
            with self.subTest(version=version):
                self.assertFalse(publication_authorized(
                    {**self.request, "version": version}, version))


if __name__ == "__main__":
    unittest.main()
