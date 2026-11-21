import '../models/boq_models.dart';

abstract interface class BoqRepository {
  Future<BoqStudioData> fetchStudio();
  Future<BoqDocument> fetchBoq(String boqId);
  Future<BoqDocument> generate(BoqGenerationBrief brief);
}
