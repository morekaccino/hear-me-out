import '../core/learning/content_pack.dart';
import 'note_reading/templates.dart';
import 'rhythm/templates.dart';
import 'theory/templates.dart';

/// The content pack the app ships with today.
///
/// New topics add their templates to this list. The composer never changes.
const ContentPack appContentPack = ContentPack(
  id: 'hear_me_out.reading.v4',
  templates: [
    ...noteReadingTemplates,
    ...fretboardTemplates,
    ...theoryTemplates,
    ...harmonyTemplates,
    ...earTemplates,
    ...techniqueTemplates,
    ...sightReadingTemplates,
    ...repertoireTemplates,
    ...improvisationTemplates,
    ...rhythmTemplates,
  ],
);
