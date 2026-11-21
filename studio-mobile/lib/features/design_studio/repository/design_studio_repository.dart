import 'dart:typed_data';

import '../models/design_models.dart';

abstract interface class DesignStudioRepository {
  Future<DesignStudioData> fetchStudio();
  Future<DesignRecord> fetchDesign(String designId);
  Future<DesignRecord> generate(DesignBrief brief);
  Future<DesignRecord> generateTechnical(
    String designId,
    DesignDrawingType type,
  );
  Future<DesignRecord> generateThreeD(String designId, int floorNumber);
  Future<void> deleteDesign(String designId);
  Future<DesignPurchaseRequest> requestCredits({
    required String pack,
    required String utr,
    String? note,
  });
  Future<Uint8List> downloadPdf(
    String designId,
    DesignDrawingType type,
    int floorNumber,
  );
}
