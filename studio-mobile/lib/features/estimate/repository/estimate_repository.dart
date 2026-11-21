import '../models/estimate_models.dart';

abstract interface class EstimateRepository {
  Future<EstimateStudioData> fetchStudio();
  Future<EstimateDocument> fetchEstimate(String estimateId);
  Future<EstimateDocument> create(EstimateBrief brief);
}
