from types import SimpleNamespace

import pytest

from candidate_number_utils import candidate_number


@pytest.mark.parametrize('code,expected', [
    ('RSO-MDIR', 'MDIR'), ('RSO-IRTS', 'IRTS'), ('RSO-RTNM', 'RTNM'),
    ('mdir-rso', 'MDIR'),
])
@pytest.mark.parametrize('sequence,suffix', [(1, '001'), (10, '010'), (100, '100'), (1000, '1000')])
def test_training_initials_and_at_most_two_leading_zeros(code, expected, sequence, suffix):
    assert candidate_number(code, sequence) == f'NIRPR-{expected}-{suffix}'


@pytest.mark.asyncio
async def test_allocator_keeps_sequence_after_legacy_and_course_numbers():
    from main import allocate_candidate_identity

    class DB:
        flushed = False
        queries = 0

        async def flush(self):
            self.flushed = True

        async def execute(self, query):
            assert self.flushed
            self.queries += 1
            if self.queries == 1:
                return SimpleNamespace(scalar_one_or_none=lambda: 'RSO-MDIR')
            return SimpleNamespace(all=lambda: [
                ('NIRPR-CAN-000099', 'NIRPR-EXM-000099'),
                ('NIRPR-IRTS-100', 'NIRPR-EXM-000100'),
            ])

    identity = await allocate_candidate_identity(DB(), 5)
    assert identity.candidate_number == 'NIRPR-MDIR-101'
    assert identity.examination_number == 'NIRPR-EXM-000101'


@pytest.mark.parametrize('code', ['', 'RSO', '---'])
def test_missing_initials_are_not_replaced_by_a_generic_number(code):
    with pytest.raises(ValueError):
        candidate_number(code, 1)
