from otic_cloud.teaching_policy import profile_for, teaching_context

def test_depth_matches_the_actual_request():
    assert profile_for('Explain photosynthesis fully').mode == 'explanation'
    assert profile_for('Give me an example of nutrition').mode == 'example'
    assert profile_for('Explain photosynthesis more simply').mode == 'simple'
    assert profile_for('Explain photosynthesis fully').max_tokens > profile_for('Explain it briefly').max_tokens

def test_context_is_relevant_and_corrects_the_specific_misconception():
    notes=teaching_context('Give me an example', ['Nutrition Types and Nutrient Compounds'])
    assert 'a herbivore AND a heterotroph' in notes
    assert 'Worked example' in notes
    assert 'ACCURACY CHECKS' not in teaching_context('Explain earthquakes', ['Earthquakes'])

def test_teaching_plan_does_not_force_irrelevant_detail_or_reveal_check_answers():
    plan=profile_for('What is convection?').instruction
    assert 'only headings that serve' in plan
    assert 'unanswered' in plan
    assert 'Do not invent facts' in plan