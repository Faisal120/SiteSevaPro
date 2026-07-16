from abc import ABC
from abc import abstractmethod


class BaseMutation(ABC):

    @abstractmethod
    def apply(
        self,
        rooms,
        plot,
        zones,
    ):
        pass